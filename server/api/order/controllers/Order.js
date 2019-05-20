'use strict';

const stripe = require('stripe')('sk_test_Pa1UOJBiv47JinN0tHiPwVSL');
const uuid = require('uuid/v4');

/**
 * Order.js controller
 *
 * @description: A set of functions called "actions" for managing `Order`.
 */

module.exports = {

  /**
   * Retrieve order records.
   *
   * @return {Object|Array}
   */

  find: async (ctx) => {
    if (ctx.query._q) {
      return strapi.services.order.search(ctx.query);
    } else {
      return strapi.services.order.fetchAll(ctx.query);
    }
  },

  /**
   * Retrieve a order record.
   *
   * @return {Object}
   */

  findOne: async (ctx) => {
    if (!ctx.params._id.match(/^[0-9a-fA-F]{24}$/)) {
      return ctx.notFound();
    }

    return strapi.services.order.fetch(ctx.params);
  },

  /**
   * Count order records.
   *
   * @return {Number}
   */

  count: async (ctx) => {
    return strapi.services.order.count(ctx.query);
  },

  /**
   * Create a/an order record.
   *
   * @return {Object}
   */

  create: async (ctx) => {
    const { amount, products, customer, source } = ctx.request.body;
    const { email } = ctx.state.user;

    const charge = {
      // Convert a price which we have in dollars to cents
      amount: Number(amount) * 100,
      currency: 'usd',
      // customerId
      customer,
      //cardToken
      source,
      // it works for live Api keys only
      receipt_email: email
    };

    // Next we want to ensure that this charge isn't processed twice
    // We don't double charge user's card through some error we made in the code
    // https://stripe.com/docs/api/idempotent_requests
    const idempotencyKey = uuid(); // id which ensures that each charge is unque
    await stripe.charges.create(charge, {
      idempotency_key: idempotencyKey
    });
    return strapi.services.order.add({
      amount,
      products: JSON.parse(products),
      user: ctx.state.user
    });
  },

  /**
   * Update a/an order record.
   *
   * @return {Object}
   */

  update: async (ctx, next) => {
    return strapi.services.order.edit(ctx.params, ctx.request.body);
  },

  /**
   * Destroy a/an order record.
   *
   * @return {Object}
   */

  destroy: async (ctx, next) => {
    return strapi.services.order.remove(ctx.params);
  }
};
